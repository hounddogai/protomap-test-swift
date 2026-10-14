@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryPendingIsolationExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.PendingIsolationExceptionStore = BedManagement.newMemoryPendingIsolationExceptionStore()
        let item = BedManagement.newPendingIsolationException("code-661", label: "label-787")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
