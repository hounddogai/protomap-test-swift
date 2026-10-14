import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default program rollup is in its life cycle.
    enum DefaultProgramRollupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One default program rollup, with what the planners need to act on it.
    final class DefaultProgramRollup {
        var code: String
        var label: String
        var visitMinutes: Int
        var phone: String
        var checksum: String
        var specialty: String
        var tags: [String]
        var segment: String
        var rate: Double
        var status: DefaultProgramRollupStatus

        init(code: String, label: String, visitMinutes: Int, phone: String, checksum: String, specialty: String, tags: [String], segment: String, rate: Double, status: DefaultProgramRollupStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.phone = phone
            self.checksum = checksum
            self.specialty = specialty
            self.tags = tags
            self.segment = segment
            self.rate = rate
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

        func canMoveTo(_ next: DefaultProgramRollupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == DefaultProgramRollupStatus.revoked || next == DefaultProgramRollupStatus.expired
            case .revoked:
                return next == DefaultProgramRollupStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultProgramRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default program rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveLoad() -> Double {
            return ((rate + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultProgramRollup {
            return DefaultProgramRollup(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                phone: phone,
                checksum: checksum,
                specialty: specialty,
                tags: tags,
                segment: segment,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a default program rollup in status requested.
    static func newDefaultProgramRollup(_ code: String, label: String) -> DefaultProgramRollup {
        return DefaultProgramRollup(
            code: code,
            label: label,
            visitMinutes: 0,
            phone: "",
            checksum: "",
            specialty: "",
            tags: [],
            segment: "",
            rate: 0.0,
            status: DefaultProgramRollupStatus.requested
        )
    }
}
