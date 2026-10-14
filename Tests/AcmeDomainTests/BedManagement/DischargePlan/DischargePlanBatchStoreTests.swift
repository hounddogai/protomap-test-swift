@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDischargePlanBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DischargePlanBatchStore = BedManagement.newMemoryDischargePlanBatchStore()
        let item = BedManagement.newDischargePlanBatch("code-656", label: "label-890")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
