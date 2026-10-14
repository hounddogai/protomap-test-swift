@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryScheduledRevocationGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ScheduledRevocationGroupStore = Consent.newMemoryScheduledRevocationGroupStore()
        let item = Consent.newScheduledRevocationGroup("code-822", name: "name-45")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
