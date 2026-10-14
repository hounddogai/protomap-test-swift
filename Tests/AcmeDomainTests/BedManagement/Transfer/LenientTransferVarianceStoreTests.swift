@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryLenientTransferVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.LenientTransferVarianceStore = BedManagement.newMemoryLenientTransferVarianceStore()
        let item = BedManagement.newLenientTransferVariance("code-141", title: "title-315")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
