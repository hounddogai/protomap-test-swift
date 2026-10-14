@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryScheduledWitnessMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ScheduledWitnessMilestoneStore = Consent.newMemoryScheduledWitnessMilestoneStore()
        let item = Consent.newScheduledWitnessMilestone("code-874", title: "title-355")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
