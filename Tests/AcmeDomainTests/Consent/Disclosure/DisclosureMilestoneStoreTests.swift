@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureMilestoneStore = Consent.newMemoryDisclosureMilestoneStore()
        let item = Consent.newDisclosureMilestone("code-262", label: "label-890")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
