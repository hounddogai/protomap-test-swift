@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyPlanStore = Imaging.newMemoryStudyPlanStore()
        let item = Imaging.newStudyPlan("code-204", name: "name-397")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
