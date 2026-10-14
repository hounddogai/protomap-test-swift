@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationMilestoneStore = Consent.newMemoryRevocationMilestoneStore()
        let item = Consent.newRevocationMilestone("code-369", title: "title-655")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
