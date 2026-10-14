@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryScheduledRevocationDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ScheduledRevocationDigestStore = Consent.newMemoryScheduledRevocationDigestStore()
        let item = Consent.newScheduledRevocationDigest("code-300", name: "name-170")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
