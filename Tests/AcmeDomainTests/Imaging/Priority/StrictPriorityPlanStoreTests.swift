@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStrictPriorityPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StrictPriorityPlanStore = Imaging.newMemoryStrictPriorityPlanStore()
        let item = Imaging.newStrictPriorityPlan("code-170", title: "title-256")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
