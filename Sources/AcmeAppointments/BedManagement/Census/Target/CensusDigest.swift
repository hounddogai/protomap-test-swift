import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census digest is in its life cycle.
    enum CensusDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A census digest as the census team keeps it.
    final class CensusDigest {
        var code: String
        var title: String
        var facility: String
        var tags: [String]
        var allergy: String
        var updatedAt: Int
        var name: String
        var ratio: Double
        var status: CensusDigestStatus

        init(code: String, title: String, facility: String, tags: [String], allergy: String, updatedAt: Int, name: String, ratio: Double, status: CensusDigestStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.tags = tags
            self.allergy = allergy
            self.updatedAt = updatedAt
            self.name = name
            self.ratio = ratio
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

        func canMoveTo(_ next: CensusDigestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == CensusDigestStatus.ready || next == CensusDigestStatus.stopped
            case .ready:
                return next == CensusDigestStatus.draining || next == CensusDigestStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CensusDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("census digest") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedTotal() -> Double {
            return (Double(updatedAt) * ratio * 100).rounded() / 100
        }

        func copyValue() -> CensusDigest {
            return CensusDigest(
                code: code,
                title: title,
                facility: facility,
                tags: tags,
                allergy: allergy,
                updatedAt: updatedAt,
                name: name,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a census digest in status idle.
    static func newCensusDigest(_ code: String, title: String) -> CensusDigest {
        return CensusDigest(
            code: code,
            title: title,
            facility: "",
            tags: [],
            allergy: "",
            updatedAt: 0,
            name: "",
            ratio: 0.0,
            status: CensusDigestStatus.idle
        )
    }
}
