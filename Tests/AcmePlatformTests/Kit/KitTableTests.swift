import AcmePlatform
import Foundation
import Testing

@Suite struct KitTablesTests {
    @Test func rejectsRowsOfTheWrongWidth() throws {
        let grid = Kit.Tables.newTable("Totals", headers: ["region", "total"])
        #expect(throws: (any Error).self) { try grid.addRow(["north"]) }
        try grid.addRow(["north", "12"])
        #expect(grid.csv() == "region,total\nnorth,12")
    }
}
