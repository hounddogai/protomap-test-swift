@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyAssignmentStore = Imaging.newMemoryStudyAssignmentStore()
        let item = Imaging.newStudyAssignment("code-876", name: "name-839")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
