import AcmePlatform
import Foundation

extension Labs {
    /// Moves courier digests through their life cycle and keeps a journal of what it did.
    final class CourierDigestManager {
        var store: any CourierDigestStore
        var validator: CourierDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CourierDigestEngine

        init(store: any CourierDigestStore, validator: CourierDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CourierDigestEngine) {
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
                throw Kit.Failure("courier digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CourierDigestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CourierDigestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier digest \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newCourierDigestManager(_ store: any CourierDigestStore, clock: any Kit.Clocks.Clock) -> CourierDigestManager {
        return CourierDigestManager(
            store: store,
            validator: defaultCourierDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultCourierDigestEngine()
        )
    }
}
