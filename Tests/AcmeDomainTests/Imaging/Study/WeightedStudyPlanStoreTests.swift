@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWeightedStudyPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WeightedStudyPlanStore = Imaging.newMemoryWeightedStudyPlanStore()
        let item = Imaging.newWeightedStudyPlan("code-223", label: "label-576")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
