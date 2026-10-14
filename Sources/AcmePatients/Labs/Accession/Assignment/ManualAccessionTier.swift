import AcmePlatform
import Foundation

extension Labs {
    /// Where a manual accession tier is in its life cycle.
    enum ManualAccessionTierStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a manual accession tier and its current status.
    final class ManualAccessionTier {
        var code: String
        var label: String
        var reviewer: String
        var procedureCode: String
        var batchSize: Int
        var windowDays: Int
        var region: String
        var attributes: [String: String]
        var unit: String
        var updatedAt: Int
        var status: ManualAccessionTierStatus

        init(code: String, label: String, reviewer: String, procedureCode: String, batchSize: Int, windowDays: Int, region: String, attributes: [String: String], unit: String, updatedAt: Int, status: ManualAccessionTierStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.procedureCode = procedureCode
            self.batchSize = batchSize
            self.windowDays = windowDays
            self.region = region
            self.attributes = attributes
            self.unit = unit
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: ManualAccessionTierStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ManualAccessionTierStatus.suspended || next == ManualAccessionTierStatus.closed
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

        func moveTo(_ next: ManualAccessionTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual accession tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("manual accession tier") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedLoad() -> Double {
            return (Double(updatedAt) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> ManualAccessionTier {
            return ManualAccessionTier(
                code: code,
                label: label,
                reviewer: reviewer,
                procedureCode: procedureCode,
                batchSize: batchSize,
                windowDays: windowDays,
                region: region,
                attributes: attributes,
                unit: unit,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a manual accession tier in status draft.
    static func newManualAccessionTier(_ code: String, label: String) -> ManualAccessionTier {
        return ManualAccessionTier(
            code: code,
            label: label,
            reviewer: "",
            procedureCode: "",
            batchSize: 0,
            windowDays: 0,
            region: "",
            attributes: [:],
            unit: "",
            updatedAt: 0,
            status: ManualAccessionTierStatus.draft
        )
    }
}
