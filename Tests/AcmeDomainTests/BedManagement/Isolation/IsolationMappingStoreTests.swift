@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryIsolationMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.IsolationMappingStore = BedManagement.newMemoryIsolationMappingStore()
        let item = BedManagement.newIsolationMapping("code-843", title: "title-28")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
