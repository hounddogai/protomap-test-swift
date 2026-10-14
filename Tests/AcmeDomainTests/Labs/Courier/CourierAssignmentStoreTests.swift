@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierAssignmentStore = Labs.newMemoryCourierAssignmentStore()
        let item = Labs.newCourierAssignment("code-773", name: "name-322")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
