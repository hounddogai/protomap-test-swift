@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRollingConsentFormTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RollingConsentFormTargetStore = Consent.newMemoryRollingConsentFormTargetStore()
        let item = Consent.newRollingConsentFormTarget("code-869", name: "name-502")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
