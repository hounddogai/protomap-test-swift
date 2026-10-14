import AcmePlatform
import Foundation

extension Referrals {
    /// Where a default closure bundle is in its life cycle.
    enum DefaultClosureBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A default closure bundle as the closure team keeps it.
    final class DefaultClosureBundle {
        var code: String
        var label: String
        var diagnosisCode: String
        var approved: Bool
        var acuity: Int
        var createdAt: Int
        var limit: Int
        var checksum: String
        var floorValue: Double
        var source: String
        var status: DefaultClosureBundleStatus

        init(code: String, label: String, diagnosisCode: String, approved: Bool, acuity: Int, createdAt: Int, limit: Int, checksum: String, floorValue: Double, source: String, status: DefaultClosureBundleStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.approved = approved
            self.acuity = acuity
            self.createdAt = createdAt
            self.limit = limit
            self.checksum = checksum
            self.floorValue = floorValue
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultClosureBundleStatus) -> Bool {
            switch status {
            case .planned:
                return next == DefaultClosureBundleStatus.scheduled || next == DefaultClosureBundleStatus.inProgress
            case .scheduled:
                return next == DefaultClosureBundleStatus.completed || next == DefaultClosureBundleStatus.cancelled
            case .inProgress:
                return next == DefaultClosureBundleStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: DefaultClosureBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default closure bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("default closure bundle") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((floorValue - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultClosureBundle {
            return DefaultClosureBundle(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                approved: approved,
                acuity: acuity,
                createdAt: createdAt,
                limit: limit,
                checksum: checksum,
                floorValue: floorValue,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a default closure bundle in status planned.
    static func newDefaultClosureBundle(_ code: String, label: String) -> DefaultClosureBundle {
        return DefaultClosureBundle(
            code: code,
            label: label,
            diagnosisCode: "",
            approved: false,
            acuity: 0,
            createdAt: 0,
            limit: 0,
            checksum: "",
            floorValue: 0.0,
            source: "",
            status: DefaultClosureBundleStatus.planned
        )
    }
}
