import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read baseline is in its life cycle.
    enum ReadBaselineStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A read baseline as the read team keeps it.
    final class ReadBaseline {
        var code: String
        var label: String
        var tags: [String]
        var createdAt: Int
        var diagnosisCode: String
        var status: ReadBaselineStatus

        init(code: String, label: String, tags: [String], createdAt: Int, diagnosisCode: String, status: ReadBaselineStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.createdAt = createdAt
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReadBaselineStatus) -> Bool {
            switch status {
            case .requested:
                return next == ReadBaselineStatus.granted || next == ReadBaselineStatus.revoked
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ReadBaselineStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("read baseline") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> ReadBaseline {
            return ReadBaseline(
                code: code,
                label: label,
                tags: tags,
                createdAt: createdAt,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a read baseline in status requested.
    static func newReadBaseline(_ code: String, label: String) -> ReadBaseline {
        return ReadBaseline(
            code: code,
            label: label,
            tags: [],
            createdAt: 0,
            diagnosisCode: "",
            status: ReadBaselineStatus.requested
        )
    }
}
