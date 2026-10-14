import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves lenient census reviews through their life cycle and keeps a journal of what it did.
    final class LenientCensusReviewWorkflow {
        var store: any LenientCensusReviewStore
        var validator: LenientCensusReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientCensusReviewEngine

        init(store: any LenientCensusReviewStore, validator: LenientCensusReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientCensusReviewEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient census review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientCensusReviewStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient census review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientCensusReviewStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient census review \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
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

    static func newLenientCensusReviewWorkflow(_ store: any LenientCensusReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientCensusReviewWorkflow {
        return LenientCensusReviewWorkflow(
            store: store,
            validator: defaultLenientCensusReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientCensusReviewEngine(flags)
        )
    }
}
