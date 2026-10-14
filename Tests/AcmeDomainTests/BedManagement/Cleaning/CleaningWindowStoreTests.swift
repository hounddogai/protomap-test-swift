@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningWindowStore = BedManagement.newMemoryCleaningWindowStore()
        let item = BedManagement.newCleaningWindow("code-888", title: "title-635")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
