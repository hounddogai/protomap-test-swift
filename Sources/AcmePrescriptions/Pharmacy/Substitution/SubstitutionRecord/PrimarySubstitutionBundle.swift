import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary substitution bundle is in its life cycle.
    enum PrimarySubstitutionBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a primary substitution bundle and its current status.
    final class PrimarySubstitutionBundle {
        var code: String
        var name: String
        var checksum: String
        var retries: Int
        var version: Int
        var status: PrimarySubstitutionBundleStatus

        init(code: String, name: String, checksum: String, retries: Int, version: Int, status: PrimarySubstitutionBundleStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.retries = retries
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimarySubstitutionBundleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == PrimarySubstitutionBundleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimarySubstitutionBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary substitution bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedLoad() -> Double {
            return ((Double(version) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> PrimarySubstitutionBundle {
            return PrimarySubstitutionBundle(
                code: code,
                name: name,
                checksum: checksum,
                retries: retries,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary substitution bundle in status idle.
    static func newPrimarySubstitutionBundle(_ code: String, name: String) -> PrimarySubstitutionBundle {
        return PrimarySubstitutionBundle(
            code: code,
            name: name,
            checksum: "",
            retries: 0,
            version: 0,
            status: PrimarySubstitutionBundleStatus.idle
        )
    }
}
