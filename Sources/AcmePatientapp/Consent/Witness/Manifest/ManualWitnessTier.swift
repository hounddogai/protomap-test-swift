import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual witness tier is in its life cycle.
    enum ManualWitnessTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a manual witness tier and its current status.
    final class ManualWitnessTier {
        var code: String
        var title: String
        var batchSize: Int
        var approved: Bool
        var summary: String
        var status: ManualWitnessTierStatus

        init(code: String, title: String, batchSize: Int, approved: Bool, summary: String, status: ManualWitnessTierStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.approved = approved
            self.summary = summary
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

        func canMoveTo(_ next: ManualWitnessTierStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ManualWitnessTierStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ManualWitnessTierStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualWitnessTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual witness tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> ManualWitnessTier {
            return ManualWitnessTier(
                code: code,
                title: title,
                batchSize: batchSize,
                approved: approved,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual witness tier in status new.
    static func newManualWitnessTier(_ code: String, title: String) -> ManualWitnessTier {
        return ManualWitnessTier(
            code: code,
            title: title,
            batchSize: 0,
            approved: false,
            summary: "",
            status: ManualWitnessTierStatus.new
        )
    }
}
