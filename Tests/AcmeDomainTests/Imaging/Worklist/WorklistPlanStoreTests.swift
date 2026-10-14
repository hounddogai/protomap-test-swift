@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistPlanStore = Imaging.newMemoryWorklistPlanStore()
        let item = Imaging.newWorklistPlan("code-859", title: "title-905")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
