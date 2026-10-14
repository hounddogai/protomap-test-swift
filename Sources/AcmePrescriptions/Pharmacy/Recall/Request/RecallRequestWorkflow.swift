import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall requests through their life cycle and keeps a journal of what it did.
    final class RecallRequestService {
        var store: any RecallRequestStore
        var validator: RecallRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RecallRequestEngine

        init(store: any RecallRequestStore, validator: RecallRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RecallRequestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallRequestStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallRequestStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall request \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newRecallRequestService(_ store: any RecallRequestStore, clock: any Kit.Clocks.Clock) -> RecallRequestService {
        return RecallRequestService(
            store: store,
            validator: defaultRecallRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultRecallRequestEngine()
        )
    }
}
