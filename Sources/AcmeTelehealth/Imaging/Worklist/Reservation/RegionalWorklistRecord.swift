import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional worklist record is in its life cycle.
    enum RegionalWorklistRecordStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a regional worklist record and its current status.
    final class RegionalWorklistRecord {
        var code: String
        var label: String
        var checksum: String
        var payer: String
        var category: String
        var title: String
        var expiresAt: Int
        var status: RegionalWorklistRecordStatus

        init(code: String, label: String, checksum: String, payer: String, category: String, title: String, expiresAt: Int, status: RegionalWorklistRecordStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.payer = payer
            self.category = category
            self.title = title
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalWorklistRecordStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == RegionalWorklistRecordStatus.done
            case .running:
                return next == RegionalWorklistRecordStatus.done || next == RegionalWorklistRecordStatus.failed
            case .done:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalWorklistRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional worklist record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> RegionalWorklistRecord {
            return RegionalWorklistRecord(
                code: code,
                label: label,
                checksum: checksum,
                payer: payer,
                category: category,
                title: title,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a regional worklist record in status new.
    static func newRegionalWorklistRecord(_ code: String, label: String) -> RegionalWorklistRecord {
        return RegionalWorklistRecord(
            code: code,
            label: label,
            checksum: "",
            payer: "",
            category: "",
            title: "",
            expiresAt: 0,
            status: RegionalWorklistRecordStatus.new
        )
    }
}
