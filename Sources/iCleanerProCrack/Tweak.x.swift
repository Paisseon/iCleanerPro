import Orion
import iCleanerProCrackC
import UIKit
import CommonCrypto

extension String {
	var md5: String { // https://stackoverflow.com/questions/55356220/get-string-md5-in-swift-5
		let data = Data(self.utf8)
		let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
			var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
			CC_MD5(bytes.baseAddress, CC_LONG(data.count), &hash)
			return hash
		}
		return hash.map { String(format: "%02x", $0) }.joined()
	}
}

func getUDID() -> String { // stolen from Sileo lol
	let gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY)
	typealias MGCopyAnswerFunc = @convention(c) (CFString) -> CFString
	let MGCopyAnswer = unsafeBitCast(dlsym(gestalt, "MGCopyAnswer"), to: MGCopyAnswerFunc.self)
	let udid = MGCopyAnswer("UniqueDeviceID" as CFString) as String
	return udid.padding(toLength: 40, withPad: "0", startingAt: 0)
}

class iCleanerHook:ClassHook<NSURL> {
	static func hookWillActivate() -> Bool { // the orion equivalent of %ctor
		let udid = Array(getUDID()) // convert the udid string to an array because substrings in swift suck
		let x1 = String(udid[18..<23]) // get the 18th-23rd characters
		let x2 = String(udid[0..<27]) // get all characters up to the 27th
		let x3 = String(udid[13..<23]) // and so on
		let x4 = String(udid[31...]) // and so forth
		let key = "\(x1)\(x2)\(x3)\(x4)".md5 // then put them all together and md5 it. this is how icleaner pro determines registration codes
		UserDefaults.standard.set(key, forKey: "lastRequestValue") // write to the preferences from which icleaner reads
		do {
			try key.write(
				toFile: "/var/mobile/Library/iCleaner/license.cached",
				atomically: true,
				encoding: .utf8) // abd write to the cache file for ease of use
		} catch {
			print("Is the dere part here yet?") // i love the villainess is based
		}
		return true
	}
	
	func initWithString(_ arg0: String) -> NSURL {
		if arg0.contains("ib-soft.net/icleaner") { // this should be every call but for safety...
			return orig.initWithString("http://127.0.0.1")
			// redirect server calls to localhost
		} else {
			return orig.initWithString(arg0)
		}
	}
}