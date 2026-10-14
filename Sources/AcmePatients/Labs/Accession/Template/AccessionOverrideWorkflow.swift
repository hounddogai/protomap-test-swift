import AcmePlatform
import Foundation

extension Labs {
    /// Moves accession overrides through their life cycle and keeps a journal of what it did.
    final class AccessionOverrideService {
        var store: any AccessionOverrideStore
        var validator: AccessionOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AccessionOverrideEngine

        init(store: any AccessionOverrideStore, validator: AccessionOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AccessionOverrideEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AccessionOverrideStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AccessionOverrideStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession override \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newAccessionOverrideService(_ store: any AccessionOverrideStore, clock: any Kit.Clocks.Clock) -> AccessionOverrideService {
        return AccessionOverrideService(
            store: store,
            validator: defaultAccessionOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultAccessionOverrideEngine()
        )
    }
}
