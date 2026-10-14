@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDefaultRevocationMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DefaultRevocationMilestoneStore = Consent.newMemoryDefaultRevocationMilestoneStore()
        let item = Consent.newDefaultRevocationMilestone("code-672", title: "title-340")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
