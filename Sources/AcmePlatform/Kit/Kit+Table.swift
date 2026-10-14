import Foundation

extension Kit.Tables {
    public final class Table {
        public var title: String
        public var headers: [String]
        public var rows: [[String]]

        public init(title: String, headers: [String], rows: [[String]]) {
            self.title = title
            self.headers = headers
            self.rows = rows
        }

        public func addRow(_ cells: [String]) throws {
            if cells.count != headers.count {
                throw Kit.Failure("row has \(cells.count) cells, table \(title) has \(headers.count) columns")
            }
            rows.append(cells)
        }

        public func widths() -> [Int] {
            var widths: [Int] = []
            for header in headers {
                widths.append(header.count)
            }
            for row in rows {
                for i in 0..<row.count {
                    if row[i].count > widths[i] {
                        widths[i] = row[i].count
                    }
                }
            }
            return widths
        }

        public func render() -> String {
            let widths = self.widths()
            var lines: [String] = [title]
            var head: [String] = []
            for i in 0..<headers.count {
                head.append(headers[i] + String(repeating: " ", count: Swift.max(0, widths[i] - headers[i].count)))
            }
            lines.append(head.joined(separator: " | "))
            for row in rows {
                var padded: [String] = []
                for i in 0..<row.count {
                    padded.append(row[i] + String(repeating: " ", count: Swift.max(0, widths[i] - row[i].count)))
                }
                lines.append(padded.joined(separator: " | "))
            }
            return lines.joined(separator: "\n")
        }

        public func csv() -> String {
            var lines: [String] = [headers.joined(separator: ",")]
            for row in rows {
                lines.append(row.joined(separator: ","))
            }
            return lines.joined(separator: "\n")
        }
    }

    public static func newTable(_ title: String, headers: [String]) -> Table {
        return Table(title: title, headers: headers, rows: [])
    }
}
