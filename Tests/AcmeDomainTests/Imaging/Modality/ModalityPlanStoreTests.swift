@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityPlanStore = Imaging.newMemoryModalityPlanStore()
        let item = Imaging.newModalityPlan("code-872", title: "title-261")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
