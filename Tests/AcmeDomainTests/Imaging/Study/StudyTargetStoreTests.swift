@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyTargetStore = Imaging.newMemoryStudyTargetStore()
        let item = Imaging.newStudyTarget("code-173", label: "label-386")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
