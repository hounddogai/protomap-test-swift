@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessAuditStore = Consent.newMemoryWitnessAuditStore()
        let item = Consent.newWitnessAudit("code-272", title: "title-483")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
