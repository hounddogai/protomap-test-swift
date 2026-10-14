@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLenientReadAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LenientReadAssignmentStore = Imaging.newMemoryLenientReadAssignmentStore()
        let item = Imaging.newLenientReadAssignment("code-135", name: "name-35")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
