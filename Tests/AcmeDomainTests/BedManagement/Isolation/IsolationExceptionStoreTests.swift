@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryIsolationExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.IsolationExceptionStore = BedManagement.newMemoryIsolationExceptionStore()
        let item = BedManagement.newIsolationException("code-230", title: "title-489")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
