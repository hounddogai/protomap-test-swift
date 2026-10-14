import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range audit is in its life cycle.
    enum ReferenceRangeAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a reference range audit and its current status.
    final class ReferenceRangeAudit {
        var code: String
        var name: String
        var clinicianID: String
        var region: String
        var retries: Int
        var threshold: Double
        var country: String
        var ward: String
        var title: String
        var category: String
        var copay: Double
        var status: ReferenceRangeAuditStatus

        init(code: String, name: String, clinicianID: String, region: String, retries: Int, threshold: Double, country: String, ward: String, title: String, category: String, copay: Double, status: ReferenceRangeAuditStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.region = region
            self.retries = retries
            self.threshold = threshold
            self.country = country
            self.ward = ward
            self.title = title
            self.category = category
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferenceRangeAuditStatus) -> Bool {
            switch status {
            case .draft:
                return next == ReferenceRangeAuditStatus.suspended
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ReferenceRangeAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedTotal() -> Double {
            return ((copay + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeAudit {
            return ReferenceRangeAudit(
                code: code,
                name: name,
                clinicianID: clinicianID,
                region: region,
                retries: retries,
                threshold: threshold,
                country: country,
                ward: ward,
                title: title,
                category: category,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a reference range audit in status draft.
    static func newReferenceRangeAudit(_ code: String, name: String) -> ReferenceRangeAudit {
        return ReferenceRangeAudit(
            code: code,
            name: name,
            clinicianID: "",
            region: "",
            retries: 0,
            threshold: 0.0,
            country: "",
            ward: "",
            title: "",
            category: "",
            copay: 0.0,
            status: ReferenceRangeAuditStatus.draft
        )
    }
}
