@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningBundleStore = BedManagement.newMemoryCleaningBundleStore()
        let item = BedManagement.newCleaningBundle("code-532", title: "title-543")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
