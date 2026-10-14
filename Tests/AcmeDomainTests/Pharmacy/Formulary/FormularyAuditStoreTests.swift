@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularyAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularyAuditStore = Pharmacy.newMemoryFormularyAuditStore()
        let item = Pharmacy.newFormularyAudit("code-490", label: "label-729")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
