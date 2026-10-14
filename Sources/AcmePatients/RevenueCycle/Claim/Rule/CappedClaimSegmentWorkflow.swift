import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves capped claim segments through their life cycle and keeps a journal of what it did.
    final class CappedClaimSegmentManager {
        var store: any CappedClaimSegmentStore
        var validator: CappedClaimSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedClaimSegmentEngine

        init(store: any CappedClaimSegmentStore, validator: CappedClaimSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedClaimSegmentEngine) {
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
                throw Kit.Failure("capped claim segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedClaimSegmentStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped claim segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedClaimSegmentStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped claim segment \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newCappedClaimSegmentManager(_ store: any CappedClaimSegmentStore, clock: any Kit.Clocks.Clock) -> CappedClaimSegmentManager {
        return CappedClaimSegmentManager(
            store: store,
            validator: defaultCappedClaimSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedClaimSegmentEngine()
        )
    }
}
