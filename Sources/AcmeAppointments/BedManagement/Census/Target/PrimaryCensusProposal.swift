import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary census proposal is in its life cycle.
    enum PrimaryCensusProposalStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A primary census proposal as the census team keeps it.
    final class PrimaryCensusProposal {
        var code: String
        var title: String
        var windowDays: Int
        var patientRef: String
        var capacity: Int
        var pinned: Bool
        var ownerID: String
        var segment: String
        var category: String
        var version: Int
        var limit: Int
        var status: PrimaryCensusProposalStatus

        init(code: String, title: String, windowDays: Int, patientRef: String, capacity: Int, pinned: Bool, ownerID: String, segment: String, category: String, version: Int, limit: Int, status: PrimaryCensusProposalStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.patientRef = patientRef
            self.capacity = capacity
            self.pinned = pinned
            self.ownerID = ownerID
            self.segment = segment
            self.category = category
            self.version = version
            self.limit = limit
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

        func canMoveTo(_ next: PrimaryCensusProposalStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PrimaryCensusProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary census proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedExposure() -> Double {
            return ((Double(capacity) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCensusProposal {
            return PrimaryCensusProposal(
                code: code,
                title: title,
                windowDays: windowDays,
                patientRef: patientRef,
                capacity: capacity,
                pinned: pinned,
                ownerID: ownerID,
                segment: segment,
                category: category,
                version: version,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a primary census proposal in status new.
    static func newPrimaryCensusProposal(_ code: String, title: String) -> PrimaryCensusProposal {
        return PrimaryCensusProposal(
            code: code,
            title: title,
            windowDays: 0,
            patientRef: "",
            capacity: 0,
            pinned: false,
            ownerID: "",
            segment: "",
            category: "",
            version: 0,
            limit: 0,
            status: PrimaryCensusProposalStatus.new
        )
    }
}
