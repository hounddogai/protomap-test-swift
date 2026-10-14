@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryGlobalCareProtocolAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.GlobalCareProtocolAssignmentStore = Imaging.newMemoryGlobalCareProtocolAssignmentStore()
        let item = Imaging.newGlobalCareProtocolAssignment("code-590", title: "title-258")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
