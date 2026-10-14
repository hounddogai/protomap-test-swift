@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryGlobalWorklistPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.GlobalWorklistPlanStore = Imaging.newMemoryGlobalWorklistPlanStore()
        let item = Imaging.newGlobalWorklistPlan("code-684", label: "label-835")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
