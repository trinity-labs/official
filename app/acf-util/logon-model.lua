local mymodule = {}

session = require("session")
html = require("acf.html")
fs = require("acf.fs")
roles = require("roles")
authenticator = require("authenticator")

-- Write logon timestamp in a file
local function write_log(username, ip, login_time)
    local file = io.open("../../www/skins/dashboard/logs/logon/logons.txt", "a") -- Append
    if file then
        file:write(string.format("User: %s | IP: %s | Time: %s\n", username, ip, login_time))
        file:close()
    else
        error("Impossible d'ouvrir le fichier de log.")
    end
end

-- Report the logon status
mymodule.status = function(self)
    local result = cfe({ type="group", value={}, label="Logon Status" })
    result.value.username = cfe({ label="User Name" })
    result.value.sessionid = cfe({ value=self.sessiondata.id or "", label="Session ID" })

    if self.sessiondata.userinfo then
        result.value.username.value = self.sessiondata.userinfo.username or ""
    end
    return result
end

-- Logoff the user by deleting session data
mymodule.logoff = function(self)
    local result = session.unlink_session(self.conf.sessiondir, self.sessiondata.id)
    local success = (result ~= nil)
    for a,b in pairs(self.sessiondata) do
        self.sessiondata[a] = nil
    end
    return cfe({ type="boolean", value=success, label="Logoff Success" })
end

mymodule.get_logon = function(self, clientdata)
    local cmdresult = cfe({ type="group", value={}, label="Logon" })
    cmdresult.value.userid = cfe({ type="text", value=self.clientdata.userid or "", label="User ID", seq=1 })
    cmdresult.value.password = cfe({ type="password", label="Password", seq=2 })
    cmdresult.value.redir = cfe({ type="hidden", value=self.clientdata.redir, label="" })
    return cmdresult
end

-- Log on new user if possible and set up userinfo in session
mymodule.logon = function(self, logon)
    logon.errtxt = "Logon Attempt Failed"
    local countevent = session.count_events(self.conf.sessiondir, logon.value.userid.value, self.conf.clientip, self.conf.lockouttime, self.conf.lockouteventlimit)

    if countevent then
        session.record_event(self.conf.sessiondir, logon.value.userid.value, self.conf.clientip)
        io.write("Status: 403 Forbidden\n")
    end

    if false == countevent then
        if authenticator.authenticate(self, logon.value.userid.value, logon.value.password.value) then
            -- Ne pas toucher à la session existante ou aux données de session
            -- Simplement ajouter l'écriture dans un fichier sans affecter la logique de connexion

            -- Récupérer l'heure actuelle et l'adresse IP
            local login_time = os.date("%Y-%m-%d %H:%M:%S")
            local user_ip = self.conf.clientip

            -- Écrire dans le fichier de log
            write_log(logon.value.userid.value, user_ip, login_time)

            -- Conserver la logique originale de la session
            session.unlink_session(self.conf.sessiondir, self.sessiondata.id)
            for a,b in pairs(self.sessiondata) do
                if a ~= "id" then self.sessiondata[a] = nil end
            end
            self.sessiondata.id = session.random_hash(512)
            local t = authenticator.get_userinfo(self, logon.value.userid.value)
            self.sessiondata.userinfo = {}
            for name,value in pairs(t) do
                self.sessiondata.userinfo[name] = value
            end

            logon.errtxt = nil
        else
            session.record_event(self.conf.sessiondir, logon.value.userid.value, self.conf.clientip)
            io.write("Status: 403 Forbidden\n")
        end
    end
    return logon
end

mymodule.list_users = function(self)
    return cfe({ type="list", value=authenticator.list_users(self), label="Users" })
end

return mymodule
