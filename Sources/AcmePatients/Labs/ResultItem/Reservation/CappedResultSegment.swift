import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped result segment is in its life cycle.
    enum CappedResultSegmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One capped result segment, with what the planners need to act on it.
    final class CappedResultSegment {
        var code: String
        var label: String
        var ownerID: String
        var endsAt: Int
        var attributes: [String: String]
        var facility: String
        var country: String
        var region: String
        var diagnosisCode: String
        var status: CappedResultSegmentStatus

        init(code: String, label: String, ownerID: String, endsAt: Int, attributes: [String: String], facility: String, country: String, region: String, diagnosisCode: String, status: CappedResultSegmentStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.endsAt = endsAt
            self.attributes = attributes
            self.facility = facility
            self.country = country
            self.region = region
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: CappedResultSegmentStatus) -> Bool {
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
                return next == CappedResultSegmentStatus.ready || next == CappedResultSegmentStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CappedResultSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped result segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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
            return Double(endsAt)
        }

        func copyValue() -> CappedResultSegment {
            return CappedResultSegment(
                code: code,
                label: label,
                ownerID: ownerID,
                endsAt: endsAt,
                attributes: attributes,
                facility: facility,
                country: country,
                region: region,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a capped result segment in status idle.
    static func newCappedResultSegment(_ code: String, label: String) -> CappedResultSegment {
        return CappedResultSegment(
            code: code,
            label: label,
            ownerID: "",
            endsAt: 0,
            attributes: [:],
            facility: "",
            country: "",
            region: "",
            diagnosisCode: "",
            status: CappedResultSegmentStatus.idle
        )
    }
}
