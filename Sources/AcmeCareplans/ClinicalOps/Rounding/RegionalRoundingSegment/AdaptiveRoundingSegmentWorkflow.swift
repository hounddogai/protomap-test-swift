import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves adaptive rounding segments through their life cycle and keeps a journal of what it did.
    final class AdaptiveRoundingSegmentService {
        var store: any AdaptiveRoundingSegmentStore
        var validator: AdaptiveRoundingSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveRoundingSegmentStore, validator: AdaptiveRoundingSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive rounding segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveRoundingSegmentStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive rounding segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveRoundingSegmentStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newAdaptiveRoundingSegmentService(_ store: any AdaptiveRoundingSegmentStore, clock: any Kit.Clocks.Clock) -> AdaptiveRoundingSegmentService {
        return AdaptiveRoundingSegmentService(
            store: store,
            validator: defaultAdaptiveRoundingSegmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
