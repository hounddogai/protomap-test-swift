@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLenientDisclosureMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LenientDisclosureMilestoneStore = Consent.newMemoryLenientDisclosureMilestoneStore()
        let item = Consent.newLenientDisclosureMilestone("code-998", label: "label-611")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
