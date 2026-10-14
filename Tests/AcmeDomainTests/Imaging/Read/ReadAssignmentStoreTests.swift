@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadAssignmentStore = Imaging.newMemoryReadAssignmentStore()
        let item = Imaging.newReadAssignment("code-867", name: "name-698")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
