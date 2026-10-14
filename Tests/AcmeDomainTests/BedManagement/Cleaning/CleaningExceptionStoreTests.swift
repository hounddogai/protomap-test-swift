@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningExceptionStore = BedManagement.newMemoryCleaningExceptionStore()
        let item = BedManagement.newCleaningException("code-943", label: "label-218")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
