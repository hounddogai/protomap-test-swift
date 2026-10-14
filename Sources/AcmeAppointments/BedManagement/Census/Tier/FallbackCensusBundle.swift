import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback census bundle is in its life cycle.
    enum FallbackCensusBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a fallback census bundle and its current status.
    final class FallbackCensusBundle {
        var code: String
        var name: String
        var attributes: [String: String]
        var acuity: Int
        var encounterID: String
        var status: FallbackCensusBundleStatus

        init(code: String, name: String, attributes: [String: String], acuity: Int, encounterID: String, status: FallbackCensusBundleStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.acuity = acuity
            self.encounterID = encounterID
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

        func canMoveTo(_ next: FallbackCensusBundleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == FallbackCensusBundleStatus.stopped
            case .ready:
                return next == FallbackCensusBundleStatus.stopped
            case .draining:
                return next == FallbackCensusBundleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCensusBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback census bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback census bundle") \(code)"
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

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> FallbackCensusBundle {
            return FallbackCensusBundle(
                code: code,
                name: name,
                attributes: attributes,
                acuity: acuity,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback census bundle in status idle.
    static func newFallbackCensusBundle(_ code: String, name: String) -> FallbackCensusBundle {
        return FallbackCensusBundle(
            code: code,
            name: name,
            attributes: [:],
            acuity: 0,
            encounterID: "",
            status: FallbackCensusBundleStatus.idle
        )
    }
}
