from conans import ConanFile, AutoToolsBuildEnvironment
from conans import tools
import os

class ATSConan(ConanFile):
    name = "ats-channel"
    version = "0.1"
    settings = "os", "compiler", "build_type", "arch"
    generators = "make"
    exports_sources = "*"
    options = {"shared": [True, False], "fPIC": [True, False]}
    default_options = {"shared": False, "fPIC": False}

    def build(self):
        atools = AutoToolsBuildEnvironment(self)
        # atools.libs.append("pthread")
        atools.make()

    def package(self):
        self.copy("*.hats", dst="", src="")
        self.copy("*.dats", dst="", src="")
        self.copy("*.sats", dst="", src="")
        if self.options.shared:
            self.copy("*.so", dst="lib", keep_path=False)
        else:
            self.copy("*.a", dst="lib", keep_path=False)

    def package_info(self):
        self.cpp_info.libs = ["ats-shared-vt"]
