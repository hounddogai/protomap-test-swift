@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryScheduledStudyPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ScheduledStudyPolicyStore = Imaging.newMemoryScheduledStudyPolicyStore()
        let item = Imaging.newScheduledStudyPolicy("code-722", label: "label-341")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
